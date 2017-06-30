using UnityEngine;
using System.Collections;

public class Lens : MonoBehaviour {
	public Camera camPerson;
	public Camera camFront;
	public Transform plane;
	public Material screenMat;
	public Matrix4x4 homography;

	Matrix4x4 intrinsicsFront;


	Matrix4x4 toNDC(Matrix4x4 src, int width, int height, float znear, float zfar)
	{
		Matrix4x4 dst = Matrix4x4.zero;
		dst.m00 = 2.0f * src.m00 / width;
		dst.m02 = -(src.m02 / width) + 0.5f;
		dst.m11 = 2.0f * src.m11 / height;
		dst.m12 = -(src.m12 / height) + 0.5f;
		dst.m22 = -(znear + zfar) / (zfar - znear);
		dst.m23 = -2.0f * znear * zfar / (zfar - znear);
		dst.m32 = -1.0f;
		return dst;
	}

	Matrix4x4 intrinsicsFromFOV(int width, int height, float fovInDegrees)
	{
		Matrix4x4 intrinsics = Matrix4x4.identity;
		intrinsics.m00 = (width * 0.5f) / Mathf.Tan(fovInDegrees * 0.5f * Mathf.Deg2Rad);
		intrinsics.m02 = width * 0.5f;
		intrinsics.m11 = (height * 0.5f) / Mathf.Tan(fovInDegrees * 0.5f * Mathf.Deg2Rad);
		intrinsics.m12 = height * 0.5f;
		return intrinsics;
	}

	// Use this for initialization
	void Start () {
		int width = 512;
		int height = 512;
		camFront.targetTexture = new RenderTexture (width, height, 24, RenderTextureFormat.Default, RenderTextureReadWrite.Default);
		intrinsicsFront = intrinsicsFromFOV (width, height, camFront.fieldOfView);
		camFront.projectionMatrix = toNDC (intrinsicsFront, width, height, camFront.nearClipPlane, camFront.farClipPlane);
	}
	
	// Update is called once per frame
	void Update () {
		Quaternion rA = camPerson.transform.rotation;
		Quaternion rB = camFront.transform.rotation;
		Vector3 tA = camPerson.transform.position;
		Vector3 tB = camFront.transform.position;
		Vector3 N = plane.transform.forward;
		float d = Vector3.Dot (N, plane.transform.position);
		Matrix4x4 Ra = Matrix4x4.TRS (Vector3.zero, rA, Vector3.one);
		Matrix4x4 Rb = Matrix4x4.TRS (Vector3.zero, rB, Vector3.one);
		Vector3 deltaP = (tB - tA) / d;
		Matrix4x4 inner = Matrix4x4.identity;
		inner.SetRow (0, new Vector4(1,0,0,0) - (new Vector4 (N.x, N.y, N.z, 0) * deltaP.x));
		inner.SetRow (1, new Vector4(0,1,0,0) - (new Vector4 (N.x, N.y, N.z, 0) * deltaP.y));
		inner.SetRow (2, new Vector4(0,0,1,0) - (new Vector4 (N.x, N.y, N.z, 0) * deltaP.z));

		Matrix4x4 intrinsicsPerson = intrinsicsFromFOV (Screen.width, Screen.height, camPerson.fieldOfView);
		camPerson.projectionMatrix = toNDC (intrinsicsPerson, Screen.width, Screen.height, camPerson.nearClipPlane, camPerson.farClipPlane);

		//homography = intrinsicsFront.inverse * (Ra * (inner * Rb)) * intrinsicsPerson;
		homography = Ra * (inner * Rb);
		homography = homography.inverse;
		screenMat.SetTexture ("_MainTex", camFront.targetTexture);
		screenMat.SetVector ("_Hba0", homography.GetRow(0));
		screenMat.SetVector ("_Hba1", homography.GetRow(1));
		screenMat.SetVector ("_Hba2", homography.GetRow(2));
		screenMat.SetVector ("_resA", new Vector4(Screen.width, Screen.height,0,0));
		screenMat.SetVector ("_resB", new Vector4(camFront.targetTexture.width, camFront.targetTexture.height,0,0));
	}
}
